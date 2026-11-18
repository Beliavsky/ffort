program p
implicit none
integer(8)::a(0),b(2,0),c(1,0,2)
print *,size(shiftr(a,1)),kind(shiftr(a,1))
print *,size(shiftr(b,1)),size(shiftr(c,1))
end program
