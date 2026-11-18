program t
implicit none
character(*),parameter::a='abcdef',b=a(2:4)
if(b/='bcd'.or.len(b)/=3) error stop 1
print '(a)',b
end program
