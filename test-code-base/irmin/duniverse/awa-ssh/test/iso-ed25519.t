  $ awa_gen_key --keytype ed25519 > a.key
  $ cat a.key | tail -n1 > a.public_key
  $ cat a.key | head -n1 | cut -d' ' -f3 > a.seed
  $ ./public_key_of_seed.exe $(cat a.seed) > b.public_key
  $ diff a.public_key b.public_key
