program main
implicit none
character(3)::a(2)=["abc","def"]
character(12)::s="before"
write(s,'(a,2a)') s,a
print '(a)',s

end program
