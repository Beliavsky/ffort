program p
implicit none
character(20)::text
character(65536)::a(257)
text='257*x'
read(text,*)a
end program
