~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"G!a~>CBU,&9yB8&.k<pfkM{@E3}X.af:fEiy=6OMwR1.<sY3RE5MJ_iOF}AvAhV~"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"&,n89*7H/5D/ELGA&)(DT*{Vf46B0v%yu}ck0i5*.gKEA3!TukCqTwf0Eo@AcPmr"
  set vm_args: "rel/vm.args"
end

release :transport do
  set version: current_version(:transport)
  set applications: [
    :runtime_tools
  ]
  set commands: [
    migrate: "rel/commands/migrate.sh"
  ]
end

