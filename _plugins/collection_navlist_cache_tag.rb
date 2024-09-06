## NOTE: COPIED 1 to 1 from 'kahani' theme (aside from this comment), may be used via jekyll-extract in future ##

# A function impostering as Liquid::Tag to cache the navigation-list/page-tree inside {:collection}_navlist.yaml data file.

module Jekyll
    class NavListCaching < Liquid::Tag
        @@cached_navlists = Set.new

        def debug
            return false # Set to false to disable debugging
        end

        def initialize(tag_name, text, tokens)
            super
            @text = text
        end

        def render(context)
            site = context.registers[:site]
            page_s_collection = if @text.empty? then context.environments.first["page"]["collection"] else @text end
            pages_inside_collection = site.collections[page_s_collection]
            collection_root = Pathname.new(pages_inside_collection.directory).realpath
            site_baseurl = site.config["baseurl"]
            use_index_file_as_root = true

            return "" if @@cached_navlists.include?(page_s_collection)
            
            tree = create_navtree(pages_inside_collection, collection_root, site_baseurl, use_index_file_as_root)
            
            yaml_output_file = "#{site.source}/_data/#{page_s_collection}.yaml"
            output_dir = File.dirname(yaml_output_file)
            FileUtils.mkpath(output_dir) unless File.directory?(output_dir)
            File.open(yaml_output_file, "w") do |f|
                f.write(tree.to_yaml)
            end

            @@cached_navlists << page_s_collection

            "" # Return empty string
        end

        def create_navtree(pages, root, baseurl, use_index_file_as_root)
            tree = {}
            
            # NOTE: 
            # - both root and outfile are of type 'Pathname'
            # - '/' is appended to the keys to indicate that they are properties as they are not part of the actual path
            
            for page in pages do
                url = baseurl + page.url
                realpath = Pathname.new(page.path).realpath.relative_path_from(root)
                path = realpath
                
                if use_index_file_as_root then
                    path = path.parent if path.basename(path.extname).to_s == "index"
                end

                obj = tree
                path.each_filename do |part|
                    obj[part] = {} if obj[part].nil?
                    obj = obj[part]
                end
                obj["url/"] = url
                if !page.data["title"].nil? then
                    obj["title/"] = page.data["title"]
                end
                
    
                if debug then
                    tree["All Sites"] = [] if tree["Debug"].nil?
                    tree["All Sites"] << {
                        "url/" => url,
                        "path/" => path.to_s,
                        "basename/" => path.basename(path.extname).to_s
                    }
                end
            end

            if debug then
                tree["root-path"] = root
            end
            
            return tree
        end
    end
end

Liquid::Template.register_tag('create_navigation_list_cache_for_collection', Jekyll::NavListCaching)