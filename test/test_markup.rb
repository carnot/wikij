require File.join(File.dirname(__FILE__), *%w[helper])

context "Markup" do
  setup do
    @path = testpath("examples/test.git")
    FileUtils.rm_rf(@path)
    Grit::Repo.init_bare(@path)
    @wiki = Gollum::Wiki.new(@path)

    @commit = { :message => "Add stuff",
                :name => "Tom Preston-Werner",
                :email => "tom@github.com" }
  end

  teardown do
    FileUtils.rm_r(File.join(File.dirname(__FILE__), *%w[examples test.git]))
  end

  test "page link" do
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[Bilbo Baggins]] b", @commit)

    page = @wiki.page("Bilbo Baggins")
    output = Gollum::Markup.new(page).render
    assert_equal %{<p>a <a href="Bilbo-Baggins">Bilbo Baggins</a> b</p>\n}, output
  end

  test "image with absolute path" do
    index = @wiki.repo.index
    index.add("alpha.jpg", "hi")
    index.commit("Add alpha.jpg")
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[/alpha.jpg]] b", @commit)

    page = @wiki.page("Bilbo Baggins")
    output = Gollum::Markup.new(page).render
    assert_equal %{<p>a <img src="/alpha.jpg" /> b</p>\n}, output
  end

  test "image with relative path" do
    index = @wiki.repo.index
    index.add("greek/alpha.jpg", "hi")
    index.add("greek/Bilbo-Baggins.md", "a [[alpha.jpg]] b")
    index.commit("Add alpha.jpg")

    page = @wiki.page("Bilbo Baggins")
    output = Gollum::Markup.new(page).render
    assert_equal %{<p>a <img src="/greek/alpha.jpg" /> b</p>\n}, output
  end

  test "image with alt" do
    content = "a [[alpha.jpg|alt=Alpha Dog]] b"
    output = %{<p>a <img src="/greek/alpha.jpg" alt="Alpha Dog" /> b</p>\n}
    relative_image(content, output)
  end

  test "image with em or px dimension" do
    %w{em px}.each do |unit|
      %w{width height}.each do |dim|
        content = "a [[alpha.jpg|#{dim}=100#{unit}]] b"
        output = "<p>a <img src=\"/greek/alpha.jpg\" style=\"max-#{dim}: 100#{unit};\" /> b</p>\n"
        relative_image(content, output)
      end
    end
  end

  test "image with bogus dimension" do
    %w{width height}.each do |dim|
      content = "a [[alpha.jpg|#{dim}=100]] b"
      output = "<p>a <img src=\"/greek/alpha.jpg\" /> b</p>\n"
      relative_image(content, output)
    end
  end

  test "image with float" do
    content = "a\n\n[[alpha.jpg|float]]\n\nb"
    output = "<p>a</p>\n\n<p><div class=\"float-left;\"><div><img src=\"/greek/alpha.jpg\" /></div></div></p>\n\n<p>b</p>\n"
    relative_image(content, output)
  end

  test "image with frame" do
    content = "a\n\n[[alpha.jpg|frame]]\n\nb"
    output = "<p>a</p>\n\n<p><div class=\"frame\"><div><img src=\"/greek/alpha.jpg\" /></div></div></p>\n\n<p>b</p>\n"
    relative_image(content, output)
  end

  test "image with frame and alt" do
    content = "a\n\n[[alpha.jpg|frame|alt=Alpha]]\n\nb"
    output = "<p>a</p>\n\n<p><div class=\"frame\"><div><img src=\"/greek/alpha.jpg\" alt=\"Alpha\" /><p>Alpha</p></div></div></p>\n\n<p>b</p>\n"
    relative_image(content, output)
  end

  test "file link with absolute path" do
    index = @wiki.repo.index
    index.add("alpha.jpg", "hi")
    index.commit("Add alpha.jpg")
    @wiki.write_page("Bilbo Baggins", :markdown, "a [[Alpha|/alpha.jpg]] b", @commit)

    page = @wiki.page("Bilbo Baggins")
    output = Gollum::Markup.new(page).render
    assert_equal %{<p>a <a href="/alpha.jpg">Alpha</a> b</p>\n}, output
  end

  test "file link with relative path" do
    index = @wiki.repo.index
    index.add("greek/alpha.jpg", "hi")
    index.add("greek/Bilbo-Baggins.md", "a [[Alpha|alpha.jpg]] b")
    index.commit("Add alpha.jpg")

    page = @wiki.page("Bilbo Baggins")
    output = Gollum::Markup.new(page).render
    assert_equal %{<p>a <a href="/greek/alpha.jpg">Alpha</a> b</p>\n}, output
  end

  def relative_image(content, output)
    index = @wiki.repo.index
    index.add("greek/alpha.jpg", "hi")
    index.add("greek/Bilbo-Baggins.md", content)
    index.commit("Add alpha.jpg")

    page = @wiki.page("Bilbo Baggins")
    rendered = Gollum::Markup.new(page).render
    assert_equal output, rendered
  end
end