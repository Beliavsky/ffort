program p
implicit none
character(16),allocatable::a(:)
integer::n
allocate(a(-1:1))
a(0)="47"
read(a(0),*)n
if(n/=47)stop 1
print '(a)', "OK"
end program
