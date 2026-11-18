subroutine checkdir(dir)
character(len=*), intent(in) :: dir
integer :: unitno
! Test whether the directory exists
call get_unit(unitno)
open(unit=unitno,file=trim(dir)//"deleteme.txt",status="replace",err=1234)
! line below replaced by two lines above because g95 does not support "newunit"
! open(newunit=unitno,file=fname,status="replace",err=1234)
close (unitno)
return
       ! If doesn't exist, end gracefully
1234 write(*,*) 'Data directory, '//trim(dir)//' does not exist or could not write there!'
stop
end subroutine checkdir
!
