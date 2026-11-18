integer function num_records(filename)
! Return the number of records (lines) of a text file. 
! Milan Curcic https://github.com/modern-fortran/stock-prices/blob/392fed96a6ccb42c6398485e9ba8fb4c721b10c4/src/mod_io.f90#L14-L26
character(len=*), intent(in) :: filename
integer :: fileunit
open(newunit=fileunit, file=filename, action="read", status="old")
num_records = 0
do
   read(unit=fileunit, fmt=*, end=1)
   num_records = num_records + 1
end do
1 continue
close(unit=fileunit)
end function num_records
!
