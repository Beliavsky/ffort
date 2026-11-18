program p
implicit none
character(65536)::a(256)
a=repeat("x",65536)
write(*,*)a(:255),repeat("x",65535)
end program
