program test
implicit none
character(3)::s
integer(8)::i,j
s='abc'
i=9223372036854775807_8;j=-9223372036854775807_8
s(i:j)='ignored'
s(2:1)='ignored'
print '(a)',s
end program
