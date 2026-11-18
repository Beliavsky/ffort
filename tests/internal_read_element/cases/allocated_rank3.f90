program p
implicit none
character(16),allocatable::a(:,:,:)
integer::n
allocate(a(-1:0,3:4,-3:-2))
a(0,4,-2)="47"
read(a(0,4,-2),*)n
if(n/=47)stop 1
print '(a)', "OK"
end program
