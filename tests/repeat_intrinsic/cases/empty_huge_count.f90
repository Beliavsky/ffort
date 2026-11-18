program p
implicit none
integer(8)::n
n=9223372036854775807_8
print *,len(repeat('',n))
print '(a)', '<'//repeat('',n)//'>'
end program
