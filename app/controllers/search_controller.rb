# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    authorize :search, :index?

    @query = params[:query].to_s.strip
    @results = GlobalSearchService.call(user: Current.user, query: @query)
  end
end
