program test
implicit none
character(6)::s
integer::i,j
s='abcdef'
i=2;j=4
if(s(i:j)/='bcd') error stop 1
s(i:j)='X'
if(s/='aX  ef') error stop 2
s(2:5)=s(1:4)
if(s/='aaX  f') error stop 3
if(s(:2)/='aa'.or.s(5:)/=' f'.or.s(:)/=s) error stop 4
if(len(s(2:4))/=3.or.len(s(8:2))/=0) error stop 5
if(kind(s(i:j))/=1) error stop 6
print '(a)',s
end program
