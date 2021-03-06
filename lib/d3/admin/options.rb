### Copyright 2016 Pixar
###
###    Licensed under the Apache License, Version 2.0 (the "Apache License")
###    with the following modification; you may not use this file except in
###    compliance with the Apache License and the following modification to it:
###    Section 6. Trademarks. is deleted and replaced with:
###
###    6. Trademarks. This License does not grant permission to use the trade
###       names, trademarks, service marks, or product names of the Licensor
###       and its affiliates, except as required to comply with Section 4(c) of
###       the License and to reproduce the content of the NOTICE file.
###
###    You may obtain a copy of the Apache License at
###
###        http://www.apache.org/licenses/LICENSE-2.0
###
###    Unless required by applicable law or agreed to in writing, software
###    distributed under the Apache License with the above modification is
###    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
###    KIND, either express or implied. See the Apache License for the specific
###    language governing permissions and limitations under the Apache License.
###
###


###
module D3
  module Admin

      # all the available actions
      ACTIONS = %w{  add  edit  live  delete  info  search  report  config  help }

      # these actions write to the server and
      # need a legit admin, not one
      # listed in D3.badmins.
      #
      ACTIONS_NEEDING_ADMIN = %w{  add  edit  live  delete }

      # the possible targets to config
      CONFIG_TARGETS = %w{all jss db dist workspace pkg-id-prefix}


      TRUE_VALUES = [true, /^true$/i, 1, /^y(es)?$/i]
      FALSE_VALUES = [false, /^false$/i, nil, 0, /^no?$/i]

      DFT_REQUIRED = "---Required---"
      DFT_NONE = "none"
      DFT_PKG_TYPE = :pkg
      DFT_PKG_ID_PREFIX = "d3"
      DFT_WORKSPACE = ENV['HOME']
      DFT_EXPIRATION = 0
      DFT_LIST_TYPE = :all



      DISPLAY_TRUE_FALSE = Proc.new {|v| case v ; when *TRUE_VALUES then "true"; when *FALSE_VALUES then "false"; else "unknown" ; end }
      DISPLAY_DFT_REQUIRED = Proc.new {|v| v.to_s.empty? ? DFT_REQUIRED : v }
      DISPLAY_DFT_NONE = Proc.new{|v| v.to_s.empty? ? DFT_NONE : v }
      DISPLAY_COMMA_SEP_LIST = Proc.new{|v| DISPLAY_DFT_NONE.call JSS.to_s_and_a(v)[:stringform]  }
      DISPLAY_PKG_TYPE = Proc.new{|v| v.to_s.start_with?('d') ? 'dmg' : 'pkg' }
      DISPLAY_LIST_TYPE = Proc.new{|v| v.to_s.empty? ? DFT_LIST_TYPE : v }

      # This hash provides details about how to handle all possible CLI option
      # values for d3admin, be they input from the command-line or via a walkthru
      #
      # Each key matches a key/method in the @options OpenStruct in d3admin.
      # representing the value for that option from the commandline.
      #
      # For each one, there is a sub-hash defining these things:
      #
      #  :default => The global default value, before applying any
      #    inherited values from older pkgs, or user-specified values
      #    from the commandline or walkthru. Note these are the Ruby internal
      #    default values (e.g. nil)  NOT the cli option default values
      #    (e.g. 'n') which are defined in the d3admins parse_cli method.
      #
      #  :cli => the GetoptLong array for this commandline option
      #
      #  :label => The lable for the value when when prompting for input
      #    or showing formatted details of the pkg.
      #
      #  :display_conversion => A proc that converts the internally-used form of a value
      #     to something more human-readable
      #     (e.g. "none" instead of an empty string for a nil value)
      #
      #  :get => the get_ method from D3::Admin::Interactive that is used to prompt for
      #     a new value for the attribute.
      #
      #  :unsetable => This option can take "none" or "n" to set its value to nil
      #
      #  :validate => the method from D3::Admin::Validate used to validate the
      #     value being provided and convert it to its internally-used form
      #
      #
      OPTIONS = {

        # General
        help: {
          :default => nil,
          :cli => [ '--help', "-h", GetoptLong::NO_ARGUMENT ],
          :label => "View help",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => nil,
          :validate => nil
        },
        extended_help: {
          :default => nil,
          :cli => [ '--extended-help','-H', GetoptLong::NO_ARGUMENT ],
          :label => "View extended help",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => nil,
          :validate => nil
        },
        walkthru: {
          :default => nil,
          :cli => [ '--walkthru','-w', GetoptLong::NO_ARGUMENT ],
          :label => "Walk-through",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => nil,
          :validate => nil
        },
        auto_confirm: {
          :default => nil,
          :cli => [ '--auto-confirm','-a', GetoptLong::NO_ARGUMENT ],
          :label => "Auto-confirm",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => nil,
          :validate => nil
        },

        # Package Identification: Add/Edit/Info/Delete

        package_name: {
          :default => nil,
          :cli => [ '--package-name', '-n', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "JSS Package Name",
          :display_conversion => nil,
          :get => :get_package_name,
          :validate => :validate_package_name
        },
        filename: {
          :default => nil,
          :cli => [ '--filename', '-f', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Dist. Point Filename",
          :display_conversion => nil,
          :get => :get_filename,
          :validate => :validate_filename
        },

        # Add

        import: {
          :default => nil,
          :cli => [ '--import', "-i", GetoptLong::OPTIONAL_ARGUMENT ],
          :label => "Import existing JSS package",
          :display_conversion => nil,
          :get => :get_jss_package_for_import,
          :validate => :validate_package_for_import
        },
        no_inherit: {
          :default => nil,
          :cli => [ '--no-inherit', "-I", GetoptLong::NO_ARGUMENT ],
          :label => "Do not inherit from older pacakge",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => nil,
          :validate => nil
        },
        source_path: {
          :default => nil,
          :cli => [ '--source-path', '-s', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Source path",
          :display_conversion => DISPLAY_DFT_REQUIRED,
          :get => :get_source_path,
          :validate => :validate_source_path
        },
        package_build_type: {
          :default => DFT_PKG_TYPE,
          :cli => [ '--dmg', GetoptLong::NO_ARGUMENT ],
          :label => "Package build type",
          :display_conversion => DISPLAY_PKG_TYPE,
          :get => :get_package_build_type,
          :validate => :validate_package_build_type
        },
        pkg_preserve_owners: {
          :default => nil,
          :cli => [ '--preserve-owners', GetoptLong::NO_ARGUMENT ],
          :label => "Preserve ownership in .pkg",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => :get_pkg_preserve_owners,
          :validate => :validate_yes_no
        },
        pkg_identifier: {
          :default => nil,
          :cli => [ '--pkg-id', '-p',  GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Package identifier prefix",
          :display_conversion => nil,
          :get => :get_pkg_identifier,
          :validate => :validate_package_identifier
        },
        workspace: {
          :default => DFT_WORKSPACE,
          :cli => [ '--workspace', '-W', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Package build workspace",
          :display_conversion => nil,
          :get => :get_workspace,
          :validate => :validate_workspace
        },

        # Add/Edit
        version: {
          :default => "1",
          :cli => [ '--version', '-v', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Version",
          :display_conversion => DISPLAY_DFT_REQUIRED,
          :get => :get_version,
          :validate => :validate_version
        },
        revision: {
          :default => 1,
          :cli => [ '--revision', '-r', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Revision",
          :display_conversion => DISPLAY_DFT_REQUIRED,
          :get => :get_revision,
          :validate => :validate_revision
        },
        category: {
          :default => D3::CONFIG.jss_default_pkg_category,
          :cli => [ '--category', '-C', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Category",
          :display_conversion => nil,
          :get => :get_category,
          :unsetable => true,
          :validate => :validate_category
        },
        oses: {
          :default => nil,
          :cli => [ '--oses', '-o', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Limited to OS's",
          :display_conversion => DISPLAY_COMMA_SEP_LIST,
          :get => :get_oses,
          :unsetable => true,
          :validate => :validate_oses
        },
        cpu_type: {
          :default => nil,
          :cli => [ '--cpu_type', '-c', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Limited to CPU type",
          :display_conversion => DISPLAY_DFT_NONE,
          :get => :get_cpu_type,
          :unsetable => true,
          :validate => :validate_cpu_type
        },
        reboot: {
          :default => false,
          :cli => [ '--reboot', '-R', GetoptLong::OPTIONAL_ARGUMENT ],
          :label => "Needs Reboot",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => :get_reboot,
          :validate => :validate_yes_no
        },
        removable: {
          :default => true,
          :cli => [ '--removable', '-u',  GetoptLong::OPTIONAL_ARGUMENT ],
          :label => "Uninstallable",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => :get_removable,
          :validate => :validate_yes_no
        },
        remove_first: {
          :default => false,
          :cli => [ '--remove-first', '-F', GetoptLong::OPTIONAL_ARGUMENT ],
          :label => "Uninstalls older installs",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => :get_remove_first,
          :validate => :validate_yes_no
        },
        prohibiting_process: {
          :default => nil,
          :cli => [ '--prohibiting-process', '-x', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Installation prohibited by processes matching",
          :display_conversion => DISPLAY_DFT_NONE,
          :get => :get_prohibiting_process,
          :unsetable => true,
          :validate => :validate_prohibiting_process
        },
        auto_groups: {
          :default => nil,
          :cli => [ '--auto-groups', '-g', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Auto installed for groups",
          :display_conversion => DISPLAY_COMMA_SEP_LIST,
          :get => :get_auto_groups,
          :validate => :validate_auto_groups,
          :unsetable => true,
          :compare => Proc.new{|o,n| o.to_a.sort == n.to_a.sort}
        },
        excluded_groups: {
          :default => nil,
          :cli => [ '--excluded-groups', '-G', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Excluded for groups",
          :display_conversion => DISPLAY_COMMA_SEP_LIST,
          :get => :get_excluded_groups,
          :validate => :validate_excluded_groups,
          :unsetable => true,
          :compare => Proc.new{|o,n| o.to_a.sort == n.to_a.sort}
        },
        pre_install: {
          :default => nil,
          :cli => [ '--pre-install', '-e', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Pre-install script",
          :display_conversion => DISPLAY_DFT_NONE,
          :get => :get_pre_install_script,
          :unsetable => true,
          :validate => :validate_pre_install_script
        },
        post_install: {
          :default => nil,
          :cli => [ '--post-install', '-t', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Post-install script",
          :display_conversion => DISPLAY_DFT_NONE,
          :get => :get_post_install_script,
          :unsetable => true,
          :validate => :validate_post_install_script
        },
        pre_remove: {
          :default => nil,
          :cli => [ '--pre-remove', '-E', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Pre-uninstall script",
          :display_conversion => DISPLAY_DFT_NONE,
          :get => :get_pre_remove_script,
          :unsetable => true,
          :validate => :validate_pre_remove_script
        },
        post_remove: {
          :default => nil,
          :cli => [ '--post-remove', '-T', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Post-uninstall script",
          :display_conversion => DISPLAY_DFT_NONE,
          :get => :get_post_remove_script,
          :unsetable => true,
          :validate => :validate_post_remove_script
        },
        expiration: {
          :default => DFT_EXPIRATION,
          :cli => [ '--expiration', '-X', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Expiration",
          :display_conversion => nil,
          :get => :get_expiration,
          :unsetable => true,
          :validate => :validate_expiration
        },
        expiration_paths: {
          :default => nil,
          :cli => [ '--expiration-path', '--expiration-paths', '-P', GetoptLong::REQUIRED_ARGUMENT ],
          :label=> "Expiration Path(s)",
          :display_conversion => D3::Database::ARRAY_OF_PATHNAMES_TO_COMMA_STRING ,
          :get => :get_expiration_paths,
          :unsetable => true,
          :validate => :validate_expiration_paths
        },
        description: {
          :default => '',
          :cli => [ '--description', '-d', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Description",
          :display_conversion => Proc.new{|v| "\n----\n#{v.to_s.gsub("\r", "\n")}\n----"},
          :get => :get_description,
          :unsetable => true,
          :validate => nil
        },

        # Search and Report
        status: {
          :default => nil,
          :cli => [ '--status', '-S', GetoptLong::REQUIRED_ARGUMENT ],
          :label => "Status for search and report",
          :display_conversion => DISPLAY_LIST_TYPE,
          :get => :get_scoped_groups,
          :validate => :validate_scoped_groups
        },

        frozen: {
          :default => nil,
          :cli => [ '--frozen', '-z', GetoptLong::NO_ARGUMENT ],
          :label => "Report frozen receipts",
          :display_conversion => DISPLAY_LIST_TYPE,
          :get => :get_scoped_groups,
          :validate => :validate_scoped_groups
        },

        queue: {
          :default => nil,
          :cli => [ '--queue', '-q', GetoptLong::NO_ARGUMENT ],
          :label => "Report pending puppies rather than receipts",
          :display_conversion => DISPLAY_LIST_TYPE,
          :get => :get_scoped_groups,
          :validate => :validate_scoped_groups
        },

        computers: {
          :default => nil,
          :cli => [ '--computers', GetoptLong::NO_ARGUMENT ],
          :label => "Report targets are computers, not basenames",
          :display_conversion => DISPLAY_LIST_TYPE,
          :get => :get_scoped_groups,
          :validate => :validate_scoped_groups
        },

        groups: {
          :default => nil,
          :cli => [ '--groups', GetoptLong::NO_ARGUMENT ],
          :label => "Search targets are scoped groups, not basenames",
          :display_conversion => DISPLAY_LIST_TYPE,
          :get => :get_scoped_groups,
          :validate => :validate_scoped_groups
        },


        # Delete
        keep_scripts: {
          :default => nil,
          :cli => [ '--keep-scripts', GetoptLong::NO_ARGUMENT ],
          :label => "Keep associated scripts in Casper",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => :get_keep_scripts,
          :validate => :validate_yes_no
        },
        keep_in_jss: {
          :default => nil,
          :cli => [ '--keep-in-jss', GetoptLong::NO_ARGUMENT ],
          :label => "Keep the Casper package",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => :get_keep_in_jss,
          :validate => :validate_yes_no
        },

        # debug
        debug: {
          :default => false,
          :cli => [ '--debug', '-D', GetoptLong::NO_ARGUMENT ],
          :label => "Be more verbose",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => nil,
          :validate => :validate_yes_no
        },
        d3_version: {
          :default => false,
          :cli => [ '--d3-version', GetoptLong::NO_ARGUMENT ],
          :label => "Display the version of d3admin and its libraries",
          :display_conversion => DISPLAY_TRUE_FALSE,
          :get => nil,
          :validate => nil
        }
      }

  end # module admin
end # module D3
