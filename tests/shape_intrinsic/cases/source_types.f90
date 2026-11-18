program p
implicit none
integer(kind=8)::i(2)
real::r(3,2)
real(kind=8)::d(2,1,3)
logical::l(4)
character(5)::c(2,3)
i=0
r=0
d=0
l=.false.
c="hello"
print *,shape(i),shape(r),shape(d),shape(l),shape(c)
print *,size(shape(.true.)),size(shape("abc"))
end program
