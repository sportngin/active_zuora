require 'spec_helper'

describe "BelongsToAssociations" do

  class Blog
    include ActiveZuora::ZObject
  end

  class Comment
    include ActiveZuora::Base
    belongs_to :blog
  end

  it "should define a attribute assignment method method for the object" do
    blog = Blog.new :id => "blog1"
    comment = Comment.new :blog => blog
    expect(comment.blog_loaded?).to be_truthy
    expect(comment.blog).to eq(blog)
    expect(comment.blog_id).to eq(blog.id)
    comment.blog = nil
    expect(comment.blog_loaded?).to be_truthy
    expect(comment.blog).to be_nil
    expect(comment.blog_id).to be_nil
  end

  it "should define a attribute assignment method for the object id" do
    blog = Blog.new :id => "blog1"
    comment = Comment.new :blog => blog
    expect(comment.blog_loaded?).to be_truthy
    comment.blog_id = "blog2"
    expect(comment.blog_loaded?).to be_falsey
  end

end

