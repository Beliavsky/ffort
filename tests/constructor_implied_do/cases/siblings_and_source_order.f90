program main
implicit none
integer::i,a(9)
i=99
a=[i,(i,i=1,3),i,(i,i=6,2,-2),i]
print *,a,i
end program
