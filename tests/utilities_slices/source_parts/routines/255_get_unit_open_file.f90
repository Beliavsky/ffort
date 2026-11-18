subroutine get_unit_open_file(xfile,iunit,xaction,nrow_skip,nlines_skip_append)
! connect file xfile to iunit for action xaction
! same as subroutine open_file, except that iunit is an intent(out) argument
! set by a call to get_unit
character (len=*), intent(in)           :: xfile
integer          , intent(out)          :: iunit ! unit to which xfile is connected upon output
character (len=*), intent(in)           :: xaction
integer          , intent(in), optional :: nrow_skip
integer          , intent(in), optional :: nlines_skip_append
integer                                 :: i,ierr,junit,nlines_skip_append_
character (len=1)                       :: xact
character (len=*), parameter            :: msg="in open_file, "
call get_unit(iunit)
if (present(nlines_skip_append)) then
   nlines_skip_append_ = nlines_skip_append
else
   nlines_skip_append_ = 1
end if
if (xaction == "r" .or. xaction == "R") then
   xact = "r"
else if (xaction == "w" .or. xaction == "W") then
   xact = "w"
else
   write (*,*) msg,"need xaction equal one of ('r','R','w','W')"
   return
end if
if (xact == "r") then
   open (unit=iunit,file=xfile,action="read",status="old",iostat=ierr)
   if (ierr /= 0) then
      write (*,*) msg,"could not open for reading file '" // trim(xfile) // "', iostat =",ierr
      if (.not. file_exists(xfile)) write (*,*) "file does not exist"
!      inquire(file=xfile,exist=file_exists)
      stop
   end if
else if (xact == "w") then
   inquire (file=xfile,number=junit)
!   print*,"iunit, junit, xfile =",iunit,junit,trim(xfile)
   if (junit /= bad_unit .and. junit /= iunit) close (junit)
   if (junit /= iunit) then
!      write (*,*) "connecting ",trim(xfile)," to unit",iunit," for writing"
      if (junit == bad_unit) then
         open (unit=iunit,file=xfile,action="write",status="replace",iostat=ierr)
      else
         open (unit=iunit,file=xfile,action="write",position="append",iostat=ierr)
      end if
   end if
   if (ierr /= 0) then
      write (*,*) msg,"could not open for writing file '" // trim(xfile) // "', iostat =",ierr
      stop
   end if
   if (junit /= bad_unit) then
      do i=1,nlines_skip_append_
         write (iunit,*)
      end do
   end if
end if
if (present(nrow_skip)) then
   do i=1,nrow_skip
      if (xact == "r") then
         read (iunit,*)
      else
         write (iunit,*)
      end if
   end do
end if
end subroutine get_unit_open_file
!
