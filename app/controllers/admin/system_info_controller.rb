require 'open3'

class Admin::SystemInfoController < Admin::ApplicationController
  EXCLUDED_MOUNT_OPTIONS = [
    'nobrowse',
    'read-only',
    'ro'
  ].freeze

  EXCLUDED_MOUNT_TYPES = [
    'autofs',
    'binfmt_misc',
    'cgroup',
    'debugfs',
    'devfs',
    'devpts',
    'devtmpfs',
    'efivarfs',
    'fuse.gvfsd-fuse',
    'fuseblk',
    'fusectl',
    'hugetlbfs',
    'mqueue',
    'proc',
    'pstore',
    'rpc_pipefs',
    'securityfs',
    'sysfs',
    'tmpfs',
    'tracefs',
    'vfat'
  ].freeze

  MOUNT_REGEX = /(\S+) on (\S+) type (\S+) \(([^)]+)\)/

  Mount = Struct.new('Mount', :name, :mount_point, :mount_type, :options)
  FsStat = Struct.new('FsStats', :path, :bytes_total, :bytes_used)

  def show
    @cpus = Vmstat.cpu rescue nil
    @memory = Vmstat.memory rescue nil

    @disks = []
    mounts.each do |mount|
      mount_options = mount.options.split(',')

      next if (EXCLUDED_MOUNT_OPTIONS & mount_options).any?
      next if (EXCLUDED_MOUNT_TYPES & [mount.mount_type]).any?

      begin
        disk = fs_stat(mount.mount_point)
        @disks.push({
          bytes_total: disk.bytes_total,
          bytes_used:  disk.bytes_used,
          disk_name:   mount.name,
          mount_path:  disk.path
        })
      rescue IOError
      end
    end
  end

  def mounts
    stdout, stderr, status = Open3.capture3('mount')
    fail IOError, stderr unless status.success?
  
    stdout.lines
      .map { |line| MOUNT_REGEX.match(line) }
      .compact
      .map { |match| Mount.new(*match.captures) }
  end
  
  def fs_stat(mount_point)
    stdout, status = Open3.capture2('stat', '-c', '%s %b %a', '-f', mount_point)
    fail IOError unless status.success?
  
    block_size, blocks_total, blocks_free = stdout.split(' ').map(&:to_i)
  
    bytes_total = blocks_total * block_size
    bytes_free = blocks_free * block_size
    bytes_used = bytes_total - bytes_free
  
    FsStat.new(mount_point, bytes_total, bytes_used)
  end
end
