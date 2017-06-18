module Jekyll
  class TagPage < Page
    include Convertible
    attr_accessor :site, :pager, :name, :ext
    attr_accessor :basename, :dir, :data, :content, :output

    def initialize(site, tag, posts)
      @site = site
      @tag = tag
      self.ext = '.html'
      self.basename = 'index'
      @name = 'index.html'
      self.process(@name)
      self.read_yaml(File.join(site.source, '_layouts'), "tagChild.html")
      self.data = {
        'layout' => 'default',
        'type' => 'tag',
        'tag' => tag,
        'title' => "Posts tagged #{@tag}",
        'posts' => posts
      }
    end

    def url
      File.join("/tags", @tag, "index.html")
    end

    def write(dest_prefix, dest_suffix = nil)
      dest = dest_prefix
      dest = File.join(dest, dest_suffix) if dest_suffix
      path = File.join(dest, CGI.unescape(self.url))
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |f|
        f.write(self.output)
      end
    end

    def html?
      true
    end
  end
end