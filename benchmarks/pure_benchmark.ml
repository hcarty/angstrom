module R = Result
open Core.Std
open Core_bench.Std

let read file =
  let open Unix in
  let size = Int64.to_int_exn (stat file).st_size in
  let buf  = String.create size in
  let rec loop pos len fd =
    let n = read ~pos ~len ~buf fd in
    if n = 0 then buf else loop (pos + n) (len - n) fd
  in
  with_file ~mode:[O_RDONLY] file ~f:(fun fd ->
    loop 0 size fd)

(* For input files involving trailing numbers, .e.g, [http-requests.txt.100],
 * go into the [benchmarks/data] directory and use the [replicate] script to
 * generate the file, i.e.,
 *
 *   [./replicate http-requests.txt 100]
 *
 *)
let main () =
  let big_twitter = read "benchmarks/data/twitter.json" in
  let http_get    = read "benchmarks/data/http-requests.txt.100" in
  Command.run (Bench.make_command [
    Bench.Test.create ~name:"json" (fun () ->
      match Angstrom.parse_only RFC7159.json (`String big_twitter) with
      | R.Ok _ -> ()
      | R.Error err -> failwith err);
    Bench.Test.create ~name:"http" (fun () ->
      match Angstrom.(parse_only (skip_many RFC2616.request) (`String http_get)) with
      | R.Ok _ -> ()
      | R.Error err -> failwith err)
  ])

let () = main ()
