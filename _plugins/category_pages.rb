module Jekyll


  class TagBase < Page
    def initialize(site, base, dir, html_file)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), html_file)

      self.data['iscat'] = true
    end
  end

  class TagChildPage < TagBase
    def initialize(site, base, dir, tag)
      super(site, base, dir, 'tagChild.html')
      self.data['tag'] = tag
      category_title_prefix = site.config['category_title_prefix'] || 'Tag: '
      self.data['title'] = "#{category_title_prefix}#{tag}"
    end
  end

  class TagParentPage < TagBase
    def initialize(site, base, dir)
      super(site, base, dir, 'tagParent.html')
      self.data['title'] = 'Posts by Tag'
    end
  end

  class CategoryPageGenerator < Generator
    safe true

    def generate(site)
      tag_root_directory = site.config['tag_dir'] || 'tags'
      site.tags.each_key do |tag|
        tag_page = TagChildPage.new(site, site.source, File.join(tag_root_directory, tag), tag)
        site.pages << tag_page
      end
      site.pages << TagParentPage.new(site, site.source, tag_root_directory)
    end
  end

end
