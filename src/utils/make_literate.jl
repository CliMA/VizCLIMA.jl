using ArgParse
using Literate

function parse_commandline()
  s = ArgParseSettings()
  @add_arg_table! s begin
    "--input-file"
    help = "path to the source Julia to script to be converted into a notebook"
    arg_type = String
    required = true
    metavar = "<path>"
    "--output-dir"
    help = "path to the destination folder for the created notebook"
    arg_type = String
    required = true
    metavar = "<path>"
    "--markdown"
    help = "make a markdown file instead of a notebook"
    action = :store_true
    "--no-execution"
    help = "make a markdown or notebook file but without executing it"
    action = :store_false
  end                  
  return parse_args(s)
end                    
                       
function main()       
  parsed_args = parse_commandline()
  if parsed_args["markdown"]
    Literate.markdown(parsed_args["input-file"], outputdir=parsed_args["output-dir"]; execute=parsed_args["no-execution"])
  else
    Literate.notebook(parsed_args["input-file"], outputdir=parsed_args["output-dir"]; execute=parsed_args["no-execution"])
  end
end

main()

