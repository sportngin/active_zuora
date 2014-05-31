require 'spec_helper'

describe 'Callbacks' do

  class Book
    include ActiveZuora::ZObject
    attr_accessor :author, :title, :publisher, :reviews

    default :author, to: 'Unknown'
    default :publisher, to: 'Foo Books'
    default :reviews, to: nil
  end

  it 'does not set default value if value given' do
    Book.new(author: 'Salinger').author.should == 'Salinger'
  end

  it 'sets default value if no value given' do
    Book.new.author.should == 'Unknown'
  end

  it 'sets defaults for multiple fields' do
    Book.new.author.should == 'Unknown'
    Book.new.publisher.should == 'Foo Books'
  end

  it 'does not set default value for field without defaults' do
    Book.new.title.should be_nil
  end

  it 'sets default to nil if nil is given as default' do
    Book.new.reviews.should be_nil
  end

end
