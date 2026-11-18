write (*,fmt_a) vec("one","two","three","four")
write (*,fmt_a) vec("one","two","three","four","five")
write (*,fmt_a) vec("one","two","three","four","five","six")
write (*,fmt_a) vec("one","two","three","four","five","six","seven")
write (*,fmt_a) vec("one","two","three","four","five","six","seven","eight")
write (*,fmt_a) vec("one","two","three","four","five","six","seven","eight","nine")
write (*,fmt_a) vec("one","two","three","four","five","six","seven","eight","nine","ten")
write (*,fmt_a) [character(len=100)::"one","two","three","four","five","six","seven","eight","nine","ten"]
print*,ends_with(["foo.bin ","foo.txt ","foo.bins",".bin.abc"],".bin")
print*,all_equal(pack([2,5],[.false.,.false.])),all_equal([2]),all_equal([2,2,2]),all_equal([2,5,2])
xvec = dble([10,20,30,40])
tf   = .true.
