# name: community-hub
# about: Community Hub plugin for Discourse
# version: 0.0.1
# authors: Vinoth Kannan (vinothkannan@vinkas.com)

enabled_site_setting :community_hub_enabled

register_custom_html extraNavItem: "<li id='communities-menu-item'><a href='/communities'>Communities</a></li>"

register_asset 'stylesheets/community-hub.scss'

PLUGIN_NAME ||= 'community'.freeze

after_initialize do

  module ::CommunityHub
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace CommunityHub
    end
  end

  class CommunityHub::Community
    class << self

      def add(name, slug, description, user)

        # TODO add i18n string
        raise StandardError.new "community.missing.name" if name.blank?
        raise StandardError.new "community.missing.slug" if slug.blank?
        raise StandardError.new "community.missing.description" if description.blank?

        id = SecureRandom.hex(16)
        record = {name: name, slug: slug, description: description, user_id: user.id}

        PluginStore.set(PLUGIN_NAME, id, record)

        record
      end

      def all()
        communities = Array.new
        result = PluginStoreRow.where(plugin_name: PLUGIN_NAME)

        return communities if result.blank?

        result.each do |c|
          communities.push(PluginStore.cast_value(c.type_name, c.value))
        end

        communities
      end

    end
  end

  CommunityHub::Engine.routes.draw do
    get "/communities" => "communities#index"
    post "/communities" => "communities#create"
  end

  Discourse::Application.routes.append do
    mount ::CommunityHub::Engine, at: "/"
  end

  require_dependency 'application_controller'

  class CommunityHub::CommunitiesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_filter :ensure_logged_in

    def create
      name = params.require(:name)
      slug = params.require(:slug)
      description = params.require(:description)
      begin
        record = CommunityHub::Community.add(name, slug, description, current_user)
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

    def index

      begin
        communities = CommunityHub::Community.all()
        render json: {communities: communities}
      rescue StandardError => e
        render_json_error e.message
      end
    end

  end

end
