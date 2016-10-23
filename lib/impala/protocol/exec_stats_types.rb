#
# Autogenerated by Thrift Compiler (0.9.3)
#
# DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
#

require 'thrift'
require 'status_types'
require 'types_types'


module Impala
  module Protocol
    module TExecState
      REGISTERED = 0
      PLANNING = 1
      QUEUED = 2
      RUNNING = 3
      FINISHED = 4
      CANCELLED = 5
      FAILED = 6
      VALUE_MAP = {0 => "REGISTERED", 1 => "PLANNING", 2 => "QUEUED", 3 => "RUNNING", 4 => "FINISHED", 5 => "CANCELLED", 6 => "FAILED"}
      VALID_VALUES = Set.new([REGISTERED, PLANNING, QUEUED, RUNNING, FINISHED, CANCELLED, FAILED]).freeze
    end

    class TExecStats
      include ::Thrift::Struct, ::Thrift::Struct_Union
      LATENCY_NS = 1
      CPU_TIME_NS = 2
      CARDINALITY = 3
      MEMORY_USED = 4

      FIELDS = {
        LATENCY_NS => {:type => ::Thrift::Types::I64, :name => 'latency_ns', :optional => true},
        CPU_TIME_NS => {:type => ::Thrift::Types::I64, :name => 'cpu_time_ns', :optional => true},
        CARDINALITY => {:type => ::Thrift::Types::I64, :name => 'cardinality', :optional => true},
        MEMORY_USED => {:type => ::Thrift::Types::I64, :name => 'memory_used', :optional => true}
      }

      def struct_fields; FIELDS; end

      def validate
      end

      ::Thrift::Struct.generate_accessors self
    end

    class TPlanNodeExecSummary
      include ::Thrift::Struct, ::Thrift::Struct_Union
      NODE_ID = 1
      FRAGMENT_ID = 2
      LABEL = 3
      LABEL_DETAIL = 4
      NUM_CHILDREN = 5
      ESTIMATED_STATS = 6
      EXEC_STATS = 7
      IS_ACTIVE = 8
      IS_BROADCAST = 9

      FIELDS = {
        NODE_ID => {:type => ::Thrift::Types::I32, :name => 'node_id'},
        FRAGMENT_ID => {:type => ::Thrift::Types::I32, :name => 'fragment_id'},
        LABEL => {:type => ::Thrift::Types::STRING, :name => 'label'},
        LABEL_DETAIL => {:type => ::Thrift::Types::STRING, :name => 'label_detail', :optional => true},
        NUM_CHILDREN => {:type => ::Thrift::Types::I32, :name => 'num_children'},
        ESTIMATED_STATS => {:type => ::Thrift::Types::STRUCT, :name => 'estimated_stats', :class => ::Impala::Protocol::TExecStats, :optional => true},
        EXEC_STATS => {:type => ::Thrift::Types::LIST, :name => 'exec_stats', :element => {:type => ::Thrift::Types::STRUCT, :class => ::Impala::Protocol::TExecStats}, :optional => true},
        IS_ACTIVE => {:type => ::Thrift::Types::LIST, :name => 'is_active', :element => {:type => ::Thrift::Types::BOOL}, :optional => true},
        IS_BROADCAST => {:type => ::Thrift::Types::BOOL, :name => 'is_broadcast', :optional => true}
      }

      def struct_fields; FIELDS; end

      def validate
        raise ::Thrift::ProtocolException.new(::Thrift::ProtocolException::UNKNOWN, 'Required field node_id is unset!') unless @node_id
        raise ::Thrift::ProtocolException.new(::Thrift::ProtocolException::UNKNOWN, 'Required field fragment_id is unset!') unless @fragment_id
        raise ::Thrift::ProtocolException.new(::Thrift::ProtocolException::UNKNOWN, 'Required field label is unset!') unless @label
        raise ::Thrift::ProtocolException.new(::Thrift::ProtocolException::UNKNOWN, 'Required field num_children is unset!') unless @num_children
      end

      ::Thrift::Struct.generate_accessors self
    end

    class TExecProgress
      include ::Thrift::Struct, ::Thrift::Struct_Union
      TOTAL_SCAN_RANGES = 1
      NUM_COMPLETED_SCAN_RANGES = 2

      FIELDS = {
        TOTAL_SCAN_RANGES => {:type => ::Thrift::Types::I64, :name => 'total_scan_ranges', :optional => true},
        NUM_COMPLETED_SCAN_RANGES => {:type => ::Thrift::Types::I64, :name => 'num_completed_scan_ranges', :optional => true}
      }

      def struct_fields; FIELDS; end

      def validate
      end

      ::Thrift::Struct.generate_accessors self
    end

    class TExecSummary
      include ::Thrift::Struct, ::Thrift::Struct_Union
      STATE = 1
      STATUS = 2
      NODES = 3
      EXCH_TO_SENDER_MAP = 4
      ERROR_LOGS = 5
      PROGRESS = 6

      FIELDS = {
        STATE => {:type => ::Thrift::Types::I32, :name => 'state', :enum_class => ::Impala::Protocol::TExecState},
        STATUS => {:type => ::Thrift::Types::STRUCT, :name => 'status', :class => ::Impala::Protocol::TStatus, :optional => true},
        NODES => {:type => ::Thrift::Types::LIST, :name => 'nodes', :element => {:type => ::Thrift::Types::STRUCT, :class => ::Impala::Protocol::TPlanNodeExecSummary}, :optional => true},
        EXCH_TO_SENDER_MAP => {:type => ::Thrift::Types::MAP, :name => 'exch_to_sender_map', :key => {:type => ::Thrift::Types::I32}, :value => {:type => ::Thrift::Types::I32}, :optional => true},
        ERROR_LOGS => {:type => ::Thrift::Types::LIST, :name => 'error_logs', :element => {:type => ::Thrift::Types::STRING}, :optional => true},
        PROGRESS => {:type => ::Thrift::Types::STRUCT, :name => 'progress', :class => ::Impala::Protocol::TExecProgress, :optional => true}
      }

      def struct_fields; FIELDS; end

      def validate
        raise ::Thrift::ProtocolException.new(::Thrift::ProtocolException::UNKNOWN, 'Required field state is unset!') unless @state
        unless @state.nil? || ::Impala::Protocol::TExecState::VALID_VALUES.include?(@state)
          raise ::Thrift::ProtocolException.new(::Thrift::ProtocolException::UNKNOWN, 'Invalid value of field state!')
        end
      end

      ::Thrift::Struct.generate_accessors self
    end

  end
end