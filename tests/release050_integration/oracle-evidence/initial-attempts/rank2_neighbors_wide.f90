program p

implicit none
character(16)::s(2,2)
s='################'
write(s(2,1),'(z16.16)')shiftr(-1_8,1)
print '(a)',s
end program
