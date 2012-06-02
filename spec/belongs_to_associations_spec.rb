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
    comment.blog_loaded?.should be_true
    comment.blog.should == blog
    comment.blog_id.should == blog.id
    comment.blog = nil
    comment.blog_loaded?.should be_true
    comment.blog.should be_nil
    comment.blog_id.should be_nil
  end

  it "should define a attribute assignment method for the object id" do
    blog = Blog.new :id => "blog1"
    comment = Comment.new :blog => blog
    comment.blog_loaded?.should be_true
    comment.blog_id = "blog2"
    comment.blog_loaded?.should be_false
  end

end

