program main
implicit none
integer::i,x(1),u,a(0)
a=[(x(i)+u,i=2,1)]
print *,size(a)
end program
