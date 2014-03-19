package 'bup' do
  options "--allow-unauthenticated"
  not_if 'which bup'
end
