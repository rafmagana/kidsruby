require 'htmlentities'

class Runner < Qt::Process
  def initialize(main)
    super
    
    @main_widget = main
    @coder = HTMLEntities.new
    
    connect(SIGNAL(:readyReadStandardOutput), &method(:read_data))
    connect(SIGNAL(:readyReadStandardError),  &method(:read_error))
  end

  def run(code = default_code, code_file_name = default_kid_code_location)
    save_kid_code(code, code_file_name)
    self.start("ruby #{code_file_name}")
  end

  def read_data
    out = self.readAllStandardOutput.data
    out.split("\n").each do |line|
      code = "updateStdOut('#{@coder.encode(line)}<br/>')"
      @main_widget.evaluateJavaScript(code)
    end
  end
  
  def read_error
    err = self.readAllStandardError.data
    err.split("\n").each do |line|
      code = "updateStdErr('#{@coder.encode(line)}<br/>')"
      @main_widget.evaluateJavaScript(code)
    end
  end

  def save_kid_code(code, code_file_name)
    ensure_tmp_dir
    
    codeFile = Qt::File.new(code_file_name)
    if !codeFile.open(Qt::File::WriteOnly | Qt::File::Text)
        Qt::MessageBox.warning(self, tr("KidsRuby Problem"),
                               tr("Oh, uh! Cannot write file %s:\n%s" %
                               [ codeFile.fileName(), codeFile.errorString() ] ) )
        return
    end
    
    codeFile.write(build_code_from_fragment(code))
    codeFile.close()
  end
  
  def build_code_from_fragment(code)
    # add any default requires for kid code
    new_code = "require '" + File.expand_path(File.dirname(__FILE__) + "/../../lib/kidsruby") + "'\n"
    new_code << code
    new_code
  end
  
  def default_code
    'puts "No code entered"'
  end
  
  def default_kid_code_location
    "#{tmp_dir}/kidcode.rb"
  end
  
  def ensure_tmp_dir
    Dir.mkdir(tmp_dir) unless Dir.exists?(tmp_dir)
  end
  
  def tmp_dir
    File.expand_path(File.dirname(__FILE__) + "/../../tmp")
  end
end
