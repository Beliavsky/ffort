program p
implicit none
real::a(2,3),b(2,3,4)
print *,shape(a,kind=size(shape(a))+2),kind(shape(a,kind=size(shape(a))+2))
print *,shape(b,kind=size(shape(b))+5),kind(shape(b,kind=size(shape(b))+5))
end program
