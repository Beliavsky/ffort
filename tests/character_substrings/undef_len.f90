program t
implicit none
character(6)::s
integer::i,j
i=2;j=4
if(len(s(i:j))/=3) error stop 1
if(kind(s(:))/=1) error stop 2
s(:)='test'
print '(a)',s
end program
