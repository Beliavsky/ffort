program test
implicit none
character(5)::s
integer(8)::i,j
s='abcde'
i=2_8;j=4_8
s(i:j)=s(3_8:5_8)
print '(a)',s
end program
