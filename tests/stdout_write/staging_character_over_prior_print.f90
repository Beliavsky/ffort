program p
implicit none
character(65536)::a(256)
a=repeat("x",65536)
print "(a)","before"
print *,a
end program
