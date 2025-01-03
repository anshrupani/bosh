require 'bosh/director/models/agent_dns_version'
require 'bosh/director/models/compiled_package'
require 'bosh/director/models/config'
require 'bosh/director/models/cpi_config'
require 'bosh/director/models/deployment'
require 'bosh/director/models/deployments_config'
require 'bosh/director/models/deployment_problem'
require 'bosh/director/models/deployment_property'
require 'bosh/director/models/director_attribute'
require 'bosh/director/models/blob'
require 'bosh/director/models/errand_run'
require 'bosh/director/models/event'
require 'bosh/director/models/instance'
require 'bosh/director/models/ip_address'
require 'bosh/director/models/links/link_provider'
require 'bosh/director/models/links/link_provider_intent'
require 'bosh/director/models/links/link_consumer'
require 'bosh/director/models/links/link_consumer_intent'
require 'bosh/director/models/links/link'
require 'bosh/director/models/links/instance_link'
require 'bosh/director/models/local_dns_blob'
require 'bosh/director/models/local_dns_encoded_az'
require 'bosh/director/models/local_dns_encoded_group'
require 'bosh/director/models/local_dns_encoded_network'
require 'bosh/director/models/local_dns_record'
require 'bosh/director/models/local_dns_alias'
require 'bosh/director/models/lock'
require 'bosh/director/models/log_bundle'
require 'bosh/director/models/orphan_disk'
require 'bosh/director/models/orphan_snapshot'
require 'bosh/director/models/orphaned_vm'
require 'bosh/director/models/package'
require 'bosh/director/models/persistent_disk'
require 'bosh/director/models/release'
require 'bosh/director/models/release_version'
require 'bosh/director/models/rendered_templates_archive'
require 'bosh/director/models/snapshot'
require 'bosh/director/models/stemcell'
require 'bosh/director/models/stemcell_upload'
require 'bosh/director/models/task'
require 'bosh/director/models/team'
require 'bosh/director/models/template'
require 'bosh/director/models/variable'
require 'bosh/director/models/variable_set'
require 'bosh/director/models/vm'
require 'bosh/director/models/network'
require 'bosh/director/models/subnet'
require 'delayed_job_sequel'

module Bosh::Director
  module Models
    VALID_ID = /^[-0-9A-Za-z_+.]+$/i
  end
end
