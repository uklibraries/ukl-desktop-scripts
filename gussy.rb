#!/usr/bin/env ruby

require 'json'
require 'nokogiri'

def component_xpath
    (1..12).collect {|number|
        %-//xmlns:dsc//xmlns:c#{sprintf "%02d", number}[xmlns:did//xmlns:container and not(.//xmlns:c#{sprintf "%02d", number+1})]-
    }.push(
       %-//xmlns:dsc//xmlns:c[xmlns:did//xmlns:container and not(.//xmlns:c)]-
    ).join('|')
end

def render(container)
    container_type = 'container'
    container_number = container.content.strip.downcase
    container_number.gsub!(/[^a-z0-9]/, '_')
    raw_type = container['type'].strip.downcase
    raw_type.gsub!(/[^a-z0-9]/, '_')
    if raw_type.length > 0
        if raw_type === 'othertype'
            raw_label = container['label'].strip.downcase
            raw_label.gsub!(/[^a-z0-9]/, '_')
            if raw_label.length > 0
                container_type = raw_label
            end
        else
            container_type = raw_type
        end
    end
    container_type.capitalize!
    [container_type, container_number].join('_')
end

def container_lists_for(xml, base)
    seen = {}
    h = {old: [], new: [], candidates: {}}
    pos = 0
    xml.xpath(component_xpath).select {|component|
        # old style
        old_path_components = [base, base]
        old_path_pieces = [base]
        component.xpath('xmlns:did/xmlns:container').each do |container|
            old_path_piece = container.content.strip.downcase
            old_path_piece.gsub!(/[^a-z0-9]/, '_')
            old_path_pieces << old_path_piece
            old_path_block = old_path_pieces.join('_')
            old_path_components << old_path_block
        end
        old_path = old_path_components.join('/')
        h[:old] << old_path

        # new style
        simple = true # hasnt_parent_attribute?
        component.xpath('xmlns:did/xmlns:container').each do |container|
            if container['parent']
                simple = false
                break
            end
        end

        path_components = [base, base]
        paths = []
        component.xpath('xmlns:did/xmlns:container').each do |container|
            if simple
                if container['parent']
                    # processCurrentDirectory
                    if path_components.length > 2
                        paths << path_components.join('/')
                        path_components = [base, base]
                    end
                end
            end
            path_components << render(container)
        end
        paths << path_components.join('/')
        h[:new] << paths

        seen[old_path] ||= {}
        h[:candidates][old_path] ||= []
        paths.each do |path|
            if not(seen[old_path].has_key?(paths))
                seen[old_path][paths] = 1
                h[:candidates][old_path] << path
            end
        end
    }
    h
end

file = ARGV[0]
base = File.basename(file, '.xml')
xml = Nokogiri::XML(IO.read file)
metadata = container_lists_for(xml, base)
File.open("../#{base}.json", 'w') do |f|
    f.puts metadata.to_json
end

File.open("../#{base}.sh", 'w') do |f|
    f.puts "#!/bin/sh"
    f.puts "DESTINATION=#{base}_copy"
    seen = {}
    move = {}
    metadata[:candidates].each_pair {|old_path, paths|
        if paths.length == 1
            path = paths[0]
            if seen.has_key? path
                f.puts "echo \"Duplicate #{path} - wanted by #{old_path} but #{seen[path]} already took it\" | tee -a $DESTINATION/#{base}.errors.txt"
            else
                seen[path] = old_path
                move[old_path] = path
                f.puts "mkdir -p $DESTINATION/data/#{path}"
                f.puts "rsync -avPO #{base}/data/#{old_path}/ $DESTINATION/data/#{path}"
            end
        else
            f.puts "echo \"Ambiguous #{old_path} - candidates: [#{paths.join(', ')}]\" | tee -a $DESTINATION/#{base}.errors.txt"
        end
    }
end
