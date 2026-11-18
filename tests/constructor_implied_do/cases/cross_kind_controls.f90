program main
implicit none
integer::i,a(3)
integer(8)::lo,hi,st
i=99
lo=1_8
hi=5_8
st=2_8
a=[(i,i=lo,hi,st)]
print *,a,i,kind(a)
end program
