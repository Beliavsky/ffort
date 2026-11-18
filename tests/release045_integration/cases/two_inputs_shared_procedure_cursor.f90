program p
implicit none
integer::u,v
character(8)::line
u=27
v=28
read(u,'(a)')line
write(*,'(a)',advance='no')trim(line)
call next_line()
read(v,'(a)')line
print '(tr1,a)',trim(line)
contains
subroutine next_line()
integer::unit_number
character(8)::word
unit_number=27
read(unit_number,'(a)')word
write(*,'(tr1,a)',advance='no')trim(word)
end subroutine
end program
