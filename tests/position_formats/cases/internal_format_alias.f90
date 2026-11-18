program p
implicit none
character(16)::s
s='(a,t2,a)'
write(s,s)'ABCD','x'
print '(a)',s
end program
