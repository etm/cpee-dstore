#!/usr/bin/ruby
#
# This file is part of CPEE-DSTORE.
#
# CPEE-DSTORE is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# CPEE-DSTORE is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with CPEE-DSTORE (file LICENSE in the main directory). If not, see
# <http://www.gnu.org/licenses/>.

require 'mimemagic'
require 'riddl/server'
require 'fileutils'

class File
  def tail(n)
    buffer = 1024
    idx = [size - buffer, 0].max
    chunks = []
    lines = 0

    begin
      seek(idx)
      chunk = read(buffer)
      lines += chunk.count("\n")
      chunks.unshift chunk
      idx -= buffer
    end while lines < ( n + 1 ) && pos != 0

    tail_of_file = chunks.join('')
    ary = tail_of_file.split("\n")
    ary[ ary.size - n, ary.size - 1 ].join("\n")
  end
end

module CPEE
  module DStore
    SERVER = File.expand_path(File.join(__dir__,'implementation.xml'))

    class DoGet < Riddl::Implementation #{{{
      def response
        file = File.join(@a[0],@r[-2],@r[-1])
        meta = file + '.mimetype'
        if File.exist?(file) && File.exist?(meta)
          f = File.open(file,'rb')
          if @p.length > 0 && @p[0].name == 'tail'
            Riddl::Parameter::Complex.new('file',File.read(meta).strip,f.tail(@p[0].value.to_i))
          else
            Riddl::Parameter::Complex.new('file',File.read(meta).strip,f)
          end
        else
          @status = 404
          nil
        end
      end
    end #}}}

    class DoPut < Riddl::Implementation #{{{
      def response
        if @p[0].name == 'append'
          mode = 'ab'
          @p.shift
        else
          mode = 'wb'
        end
        name = @r[-1]
        dir = File.join(@a[0],@r[-2])
        FileUtils.mkdir_p(dir)

        File.open(File.join(dir,name),mode) do |f|
          IO.copy_stream(@p[0].value,f)
          mime = MimeMagic.by_magic(@p[0].value.read)
          mt = if mime.nil?
            'text/plain'
          else
            mime.type
          end
          File.write(File.join(dir,name + '.mimetype'), mt)
        end

        nil
      end
    end #}}}

    def self::implementation(opts)
      opts[:data_dir] ||= File.expand_path(File.join(__dir__,'data'))

      Proc.new do
        on resource do
          on resource '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' do
            on resource '[a-z_][a-zA-Z0-9_]*' do
              run DoGet, opts[:data_dir] if get 'rfile'
              run DoPut, opts[:data_dir] if put 'ifile'
            end
          end
        end
      end
    end
  end
end
