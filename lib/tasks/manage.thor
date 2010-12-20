module Utils
  def normalize(s)
    from = %w{ ó ą ę ł ź ś ń ć ż Ó Ą Ę Ł Ź Ś Ń Ć Ż }
    to   = %w{ o a e l z s n c z O A E L Z S N C Z }
    from.each_with_index do |c, i|
      s = s.gsub(/#{c}/, to[i])
    end
    s.downcase.gsub(/[ ]/, '-')
  end
end

POSTS_ROOT = "blog"

class Category
  include Utils
  include FileUtils

  attr_reader :name, :path

  def initialize(name)
    @name = name
    @path = "#{POSTS_ROOT}/#{normalize(@name)}"
  end

  def create
    puts "Creating new category: '#{name}'"
    mkdir_p @path
    File.open("#{@path}/index.markdown", 'w+') do |f|
      f.puts <<-END
---
layout: default
title: Michał Orman - #{name}
description: Posty w kategorii #{name}
keywords: #{name}
---
# Posty w kategorii
{% assign category = site.categories.#{normalize(@name)}  %}{% include post-link.html %}
      END
    end
  end

  def remove(force = false)
    puts "Removing category: '#{@name}'"
    if Dir["#{@path}/_posts/*"].empty? || force
      rm_r @path
    else
      puts "Category contains posts, use '--force' option if you are sure you want to remove this category"
    end
  end

  def exists?
    File.exist? @path
  end
end

class Post
  include Utils
  include FileUtils

  def initialize(title, category)
    @title    = title
    @category = Category.new(category)
    @posts_path = "#{@category.path}/_posts"
    @path = "#{@posts_path}/#{normalize(@title)}.markdown"
  end

  def create
    puts "Creating post: '#{@title}' in category: '#{@category.name}'"
    # ensure cateogry exists
    @category.create unless @category.exists?
    mkdir_p @posts_path unless File.exist? @posts_path
    File.open(@path, 'w+') do |f|
      f.puts <<-END
---
layout: post
title: #{@title}
description:
keywords: #{@title} #{@category.name}
---
      END
    end
  end

  def remove
    puts "Removing post '#{@title}' in category '#{@category.name}'"
    rm @path
  end

  def exists?
    File.exists? @path
  end
end


class Blog < Thor

  desc 'create_post TITLE CATEGORY', 'Creates new post with given TITLE in given CATEGORY'

  def create_post(title, category)
    create_category category
    post = Post.new(title, category)
    unless post.exists?
      post.create
    else
      puts "Post '#{title}' in category '#{category}' already exists"
    end
  end

  desc 'remove_post TITLE CATEGORY', 'Removes post with specified TITLE in given CATEGORY'
  def remove_post(title, category)
    post = Post.new(title, category)
    if post.exists?
      post.remove
    else
      puts "Post '#{title} in category '#{category}' not exists"
    end
  end

  desc 'create_category NAME', 'Create new category with given NAME'

  def create_category(name)
    category = Category.new(name)
    unless category.exists?
      category.create
    else
      puts "Category '#{name}' already exists"
    end
  end

  desc 'remove_category NAME', 'Removes category with specified NAME if empty (use --force if want to remove non-empty category)'
  method_option :force, :type => :boolean, :aliases => '-f'

  def remove_category(name)
    category = Category.new(name)
    if category.exists?
      category.remove options[:force]
    else
      puts "Category '#{name}' not exists"
    end
  end

end