program t
implicit none
character(3)::s
integer(8)::i,j
s='abc'
i=9223372036854775807_8;j=-9223372036854775807_8
if(len(s(i:j))/=0) error stop 1
print '(a)',s(i:j)//'empty'
end program
