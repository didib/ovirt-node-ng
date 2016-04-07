#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# nodectl
#
# Copyright (C) 2016  Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author(s): Fabian Deutsch <fabiand@redhat.com>
#

import logging
import argparse
#from . import config

log = logging.getLogger()


class Application(object):
    """Use this application to manage your Node.
    The lify-cycle of a Node starts with the initialization (init).
    This assumes a thin LVM setup, and will perform some operations
    to allow later updates.
    After initializing you can inform (info) yourself about a few
    important facts (build version, ...).
    Over time you can retireve updates (update) if they are available.
    If one update is getting you into a broken state, you can rollback
    (rollback).
    """

    def __init__(self):
        pass

    def init(self, debug):
        """Perform imgbase init
        """
        raise NotImplementedError

    def info(self, debug):
        """Dump metadata and runtime informations

        - metadata
        - storage status
        - bootloader status
        """
        raise NotImplementedError

    def update(self, check, debug):
        """Check for and perform updates
        """
        raise NotImplementedError

    def rollback(self, debug):
        """Rollback to a previous image
        """
        raise NotImplementedError


class CommandMapper():
    commands = dict()

    def __init__(self):
        self.commands = dict()

    def register(self, command, meth):
        self.commands[command] = meth

    def command(self, args):
        command = args.command
        kwargs = args.__dict__
        del kwargs["command"]
        return self.commands[command](**kwargs)


def CliApplication(args=None):
    app = Application()

    parser = argparse.ArgumentParser(prog="nodectl",
                                     description=app.__doc__)
    parser.add_argument("--version", action="version")
#                        version=config.version())

    subparsers = parser.add_subparsers(title="Sub-commands", dest="command")

    parser.add_argument("--debug", action="store_true")

    sp_init = subparsers.add_parser("init",
                                    help="Intialize the required layout")

    sp_info = subparsers.add_parser("info",
                                    help="Show informations about the image")

    sp_update = subparsers.add_parser("update",
                                      help="Perform an update if updates are available")
    sp_update.add_argument("--check", action="store_true")

    sp_rollback = subparsers.add_parser("rollback",
                                        help="Rollback to the previous image")

    args = parser.parse_args(args)

    if args.debug:
        log.setLevel(logging.DEBUG)

    cmdmap = CommandMapper()
    cmdmap.register("init", app.init)
    cmdmap.register("info", app.info)
    cmdmap.register("update", app.update)
    cmdmap.register("rollback", app.rollback)

    return cmdmap.command(args)

# vim: et sts=4 sw=4: