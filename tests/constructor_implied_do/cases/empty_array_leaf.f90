program main
implicit none
integer::i,a(0),b(0)
i=77
b=[(a,i=1,3)]
print *,size(b),i
end program
