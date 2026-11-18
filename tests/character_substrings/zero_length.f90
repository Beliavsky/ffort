program test
implicit none
character(0)::s
s(:)='ignored'
if(len(s(:))/=0) error stop 1
print '(a)',s//'zero'
end program
