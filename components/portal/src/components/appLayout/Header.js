/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import AppBar from "@material-ui/core/AppBar";
import CelleryLogo from "../../img/celleryLogo.svg";
import Container from "@material-ui/core/Container";
import NavBar from "./NavBar";
import React from "react";
import Toolbar from "@material-ui/core/Toolbar";
import {withStyles} from "@material-ui/core/styles";
import * as PropTypes from "prop-types";

const styles = (theme) => ({
    appbar: {
        backgroundColor: "#ffffff",
        color: theme.palette.primary.main,
        boxShadow: "none"
    },
    headerLogo: {
        flexGrow: 1
    },
    logo: {
        fontSize: 32,
        fontWeight: 400,
        color: "#43AB00"
    },
    celleryLogo: {
        height: 40,
        verticalAlign: "middle",
        paddingRight: 2
    },
    toolbar: {
        paddingLeft: 0,
        paddingRight: 0
    },
    headerContent: {
        borderBottom: "1px solid",
        borderBottomColor: theme.palette.primary.main
    }
});

const Header = ({classes}) => (
    <header>
        <div className={classes.headerContent}>
            <Container maxWidth={"md"}>
                <AppBar position={"static"} className={classes.appbar}>
                    <Toolbar className={classes.toolbar}>
                        <div className={classes.headerLogo}>
                            <div className={classes.logo}>
                                <img src={CelleryLogo} className={classes.celleryLogo} alt={"Cellery logo"}/>
                                hub
                            </div>
                        </div>
                        <NavBar/>
                    </Toolbar>
                </AppBar>
            </Container>
        </div>
    </header>
);

Header.propTypes = {
    classes: PropTypes.object.isRequired
};

export default withStyles(styles)(Header);
