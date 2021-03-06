# Cookbook Name:: dovecot
# Library:: conf
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2013-2015 Onddo Labs, SL.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'erubis'

module DovecotCookbook
  # Helper module to generate configuration structures
  module Conf
    def self.name(str)
      str =~ /\s/ ? "\"#{str}\"" : str
    end

    def self.value(v, default = nil)
      case v
      when nil then default.to_s
      when true then 'yes'
      when false then 'no'
      when Array then v.join(' ')
      else
        v.to_s
      end
    end

    def self.attribute(conf, k, default = nil)
      v = conf[k]
      v.nil? ? "##{k} = #{value(default)}" : "#{k} = #{value(v)}"
    end

    def self.evaluate_template(template, context)
      context = context.merge(dovecot_conf: DovecotCookbook::Conf)
      eruby = Erubis::Eruby.new(template)
      eruby.evaluate(context)
    end

    def self.protocols(conf)
      # dovecot: config: Fatal: Error in configuration file
      # /etc/dovecot/dovecot.conf: protocols: Unknown protocol: lda
      ignore_protos = %w[lda]
      protos = DovecotCookbook::Protocols.list(conf) - ignore_protos
      protos.empty? ? 'none' : protos.join(' ')
    end

    def self.authdb(driver, type, conf)
      template = DovecotCookbook::Conf::Templates::AUTHDB
      evaluate_template(template, driver: driver, type: type, conf: conf)
    end

    def self.plugin(_name, conf)
      template = DovecotCookbook::Conf::Templates::PLUGIN
      evaluate_template(template, conf: conf)
    end

    def self.namespace(ns)
      template = DovecotCookbook::Conf::Templates::NAMESPACE
      evaluate_template(template, ns: ns)
    end

    def self.metrics(metrics)
      template = DovecotCookbook::Conf::Templates::METRICS
      evaluate_template(template, metrics: metrics)
    end

    def self.protocol(name, conf)
      template = DovecotCookbook::Conf::Templates::PROTOCOL
      evaluate_template(template, name: name, conf: conf)
    end

    def self.service(name, conf)
      template = DovecotCookbook::Conf::Templates::SERVICE
      evaluate_template(template, name: name, conf: conf)
    end

    def self.map(map)
      template = DovecotCookbook::Conf::Templates::MAP
      evaluate_template(template, map: map)
    end

    def self.require?(req, conf)
      case req
      when 'core' then true
      when 'imap', 'pop3', 'lmtp', 'submission' then Conf::Require.protocol?(req, conf)
      when 'sieve' then Conf::Require.plugin?('sieve', conf)
      when 'ldap' then Conf::Require.ldap?(conf['conf'])
      when 'sqlite', 'mysql', 'pgsql' then Conf::Require.db?(req, conf['conf'])
      else
        raise "Unknown configuration requirement: #{req.inspect}"
      end
    end
  end
end
